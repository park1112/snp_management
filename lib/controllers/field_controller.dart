import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/field_model.dart';
import '../models/farm_model.dart' as farm_model;
import '../services/field_service.dart';
import '../services/farm_service.dart';

class FieldController extends GetxController {
  final FieldService _fieldService = FieldService();
  final FarmService _farmService = FarmService();

  RxBool isLoading = false.obs;
  RxList<FieldModel> fields = <FieldModel>[].obs;
  RxList<FieldModel> filteredFields = <FieldModel>[].obs;
  Rx<FieldModel?> selectedField = Rx<FieldModel?>(null);

  // 선택된 농가
  Rx<farm_model.FarmModel?> selectedFarm = Rx<farm_model.FarmModel?>(null);

  // 농가 목록
  RxList<farm_model.FarmModel> farms = <farm_model.FarmModel>[].obs;

  // 검색 및 필터링 상태
  RxString searchQuery = ''.obs;
  RxString filterType = 'all'.obs; // 'all', 'farm', 'cropType', 'stage'
  RxString selectedCropType = ''.obs;
  RxString selectedStage = ''.obs;

  // 작물 종류 및 작업 단계 목록
  RxList<String> cropTypes = <String>[].obs;
  RxList<String> stages = <String>[].obs;

  // 폼 컨트롤러
  TextEditingController addressController = TextEditingController();
  TextEditingController detailAddressController = TextEditingController();
  TextEditingController areaController = TextEditingController();
  TextEditingController cropTypeController = TextEditingController();
  TextEditingController memoController = TextEditingController();

  // 면적 단위 선택
  RxString selectedAreaUnit = '평'.obs;
  final List<String> areaUnits = ['평', '제곱미터', '헥타르'];

  // 수확 예정일 선택
  Rx<DateTime?> selectedHarvestDate = Rx<DateTime?>(null);

  @override
  void onInit() {
    super.onInit();
    loadFarms();
    loadFields();
    loadCropTypes();
    loadStages();

    // 검색 쿼리 변경 감지 및 필터링
    ever(searchQuery, (_) => filterFields());
    ever(filterType, (_) => filterFields());
    ever(selectedCropType, (_) => filterFields());
    ever(selectedStage, (_) => filterFields());
    ever(
        selectedFarm,
        (_) => {
              if (selectedFarm.value != null)
                loadFieldsByFarm(selectedFarm.value!.id)
            });
  }

  @override
  void onClose() {
    // 컨트롤러 해제
    addressController.dispose();
    detailAddressController.dispose();
    areaController.dispose();
    cropTypeController.dispose();
    memoController.dispose();
    super.onClose();
  }

  // 농가 목록 로드
  Future<void> loadFarms() async {
    try {
      isLoading.value = true;

      // Stream으로 받은 농가 데이터를 한 번만 가져오기 위한 처리
      var farmsStream = _farmService.getFarms();
      farmsStream.listen((farmsList) {
        farms.value = farmsList;
        isLoading.value = false;
      }, onError: (error) {
        print('Error loading farms: $error');
        isLoading.value = false;
        Get.snackbar(
          '오류',
          '농가 목록을 불러오는 중 오류가 발생했습니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      });
    } catch (e) {
      print('Unexpected error in loadFarms: $e');
      isLoading.value = false;
    }
  }

  // 모든 농지 로드
  Future<void> loadFields() async {
    try {
      isLoading.value = true;

      // Stream으로 받은 농지 데이터를 한 번만 가져오기 위한 처리
      var fieldsStream = _fieldService.getFields();
      fieldsStream.listen((fieldsList) {
        fields.value = fieldsList;
        filterFields(); // 필터링 적용
        isLoading.value = false;
      }, onError: (error) {
        print('Error loading fields: $error');
        isLoading.value = false;
        Get.snackbar(
          '오류',
          '농지 목록을 불러오는 중 오류가 발생했습니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      });
    } catch (e) {
      print('Unexpected error in loadFields: $e');
      isLoading.value = false;
    }
  }

  // 특정 농가의 농지 로드
  Future<void> loadFieldsByFarm(String farmId) async {
    try {
      isLoading.value = true;

      // Stream으로 받은 농지 데이터를 한 번만 가져오기 위한 처리
      var fieldsStream = _fieldService.getFieldsByFarm(farmId);
      fieldsStream.listen((fieldsList) {
        fields.value = fieldsList;
        filterFields(); // 필터링 적용
        isLoading.value = false;
      }, onError: (error) {
        print('Error loading fields by farm: $error');
        isLoading.value = false;
        Get.snackbar(
          '오류',
          '농가의 농지 목록을 불러오는 중 오류가 발생했습니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      });
    } catch (e) {
      print('Unexpected error in loadFieldsByFarm: $e');
      isLoading.value = false;
    }
  }

  // 작물 종류 목록 로드
  Future<void> loadCropTypes() async {
    try {
      List<String> result = await _fieldService.getCropTypes();
      cropTypes.value = result;
    } catch (e) {
      print('Error loading crop types: $e');
    }
  }

  // 작업 단계 목록 로드
  Future<void> loadStages() async {
    try {
      List<String> result = await _fieldService.getStages();
      stages.value = result;
    } catch (e) {
      print('Error loading stages: $e');
    }
  }

  // 농지 필터링
  void filterFields() {
    try {
      if (fields.isEmpty) {
        filteredFields.value = [];
        return;
      }

      List<FieldModel> result = List.from(fields);

      // 검색어 필터링
      if (searchQuery.isNotEmpty) {
        switch (filterType.value) {
          case 'farm':
            // 농가 이름으로 필터링
            if (selectedFarm.value != null) {
              result = result
                  .where((field) => field.farmerId == selectedFarm.value!.id)
                  .toList();
            }
            break;
          case 'cropType':
            // 작물 종류로 필터링
            result = result
                .where((field) => field.cropType
                    .toLowerCase()
                    .contains(searchQuery.value.toLowerCase()))
                .toList();
            break;
          default: // 'all'
            // 농지 주소로 필터링
            result = result
                .where((field) => field.address.full
                    .toLowerCase()
                    .contains(searchQuery.value.toLowerCase()))
                .toList();
        }
      }

      // 작물 종류 필터링
      if (selectedCropType.isNotEmpty) {
        result = result
            .where((field) => field.cropType == selectedCropType.value)
            .toList();
      }

      // 작업 단계 필터링
      if (selectedStage.isNotEmpty) {
        result = result
            .where((field) => field.currentStage.stage == selectedStage.value)
            .toList();
      }

      filteredFields.value = result;
    } catch (e) {
      print('Error filtering fields: $e');
      Get.snackbar(
        '오류',
        '농지 필터링 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  // 농지 선택
  Future<void> selectField(String fieldId) async {
    try {
      isLoading.value = true;

      FieldModel? field = await _fieldService.getField(fieldId);
      selectedField.value = field;

      if (field != null) {
        // 농가 정보 로드
        farm_model.FarmModel? farm = await _farmService.getFarm(field.farmerId);
        selectedFarm.value = farm;
      }

      isLoading.value = false;
    } catch (e) {
      print('Error selecting field: $e');
      isLoading.value = false;
      Get.snackbar(
        '오류',
        '농지 정보를 불러오는 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  // 농지 등록
  Future<bool> createField() async {
    try {
      isLoading.value = true;

      // 기본 필수 필드 검증
      if (selectedFarm.value == null ||
          addressController.text.trim().isEmpty ||
          areaController.text.trim().isEmpty ||
          cropTypeController.text.trim().isEmpty) {
        Get.snackbar(
          '입력 오류',
          '농가, 주소, 면적, 작물 종류는 필수 입력 항목입니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
        isLoading.value = false;
        return false;
      }

      // 면적 검증
      double areaValue;
      try {
        areaValue = double.parse(areaController.text.trim());
        if (areaValue <= 0) {
          Get.snackbar(
            '입력 오류',
            '면적은 0보다 큰 값이어야 합니다.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
          isLoading.value = false;
          return false;
        }
      } catch (e) {
        Get.snackbar(
          '입력 오류',
          '면적에 올바른 숫자를 입력해주세요.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
        isLoading.value = false;
        return false;
      }

      // 주소 정보
      Address address = Address(
        full: addressController.text.trim(),
        detail: detailAddressController.text.trim().isNotEmpty
            ? detailAddressController.text.trim()
            : null,
        coordinates: null, // 지도에서 좌표 선택 기능 추가 필요
      );

      // 면적 정보
      Area area = Area(
        value: areaValue,
        unit: selectedAreaUnit.value,
      );

      String? fieldId = await _fieldService.createField(
        farmerId: selectedFarm.value!.id,
        address: address,
        area: area,
        cropType: cropTypeController.text.trim(),
        estimatedHarvestDate: selectedHarvestDate.value,
        memo: memoController.text.trim().isNotEmpty
            ? memoController.text.trim()
            : null,
      );

      isLoading.value = false;

      if (fieldId != null) {
        // 성공 메시지
        Get.snackbar(
          '등록 완료',
          '농지 정보가 성공적으로 등록되었습니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );

        // 폼 초기화
        resetForm();

        // 농지 목록 새로고침
        await loadFields();

        return true;
      } else {
        Get.snackbar(
          '등록 실패',
          '농지 정보 등록 중 오류가 발생했습니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
        return false;
      }
    } catch (e) {
      print('Error creating field: $e');
      isLoading.value = false;
      Get.snackbar(
        '오류',
        '농지 등록 중 오류가 발생했습니다: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return false;
    }
  }

  // 농지 정보 수정
  Future<bool> updateField(String fieldId) async {
    try {
      isLoading.value = true;

      // 기본 필수 필드 검증
      if (selectedFarm.value == null ||
          addressController.text.trim().isEmpty ||
          areaController.text.trim().isEmpty ||
          cropTypeController.text.trim().isEmpty) {
        Get.snackbar(
          '입력 오류',
          '농가, 주소, 면적, 작물 종류는 필수 입력 항목입니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
        isLoading.value = false;
        return false;
      }

      // 면적 검증
      double areaValue;
      try {
        areaValue = double.parse(areaController.text.trim());
        if (areaValue <= 0) {
          Get.snackbar(
            '입력 오류',
            '면적은 0보다 큰 값이어야 합니다.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
          isLoading.value = false;
          return false;
        }
      } catch (e) {
        Get.snackbar(
          '입력 오류',
          '면적에 올바른 숫자를 입력해주세요.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
        isLoading.value = false;
        return false;
      }

      // 주소 정보
      Address address = Address(
        full: addressController.text.trim(),
        detail: detailAddressController.text.trim().isNotEmpty
            ? detailAddressController.text.trim()
            : null,
        coordinates: null, // 지도에서 좌표 선택 기능 추가 필요
      );

      // 면적 정보
      Area area = Area(
        value: areaValue,
        unit: selectedAreaUnit.value,
      );

      bool success = await _fieldService.updateField(
        fieldId: fieldId,
        farmerId: selectedFarm.value!.id,
        address: address,
        area: area,
        cropType: cropTypeController.text.trim(),
        estimatedHarvestDate: selectedHarvestDate.value,
        memo: memoController.text.trim().isNotEmpty
            ? memoController.text.trim()
            : null,
      );

      isLoading.value = false;

      if (success) {
        // 성공 메시지
        Get.snackbar(
          '수정 완료',
          '농지 정보가 성공적으로 수정되었습니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );

        // 농지 목록 새로고침
        await loadFields();

        // 선택된 농지 정보 업데이트
        await selectField(fieldId);

        return true;
      } else {
        Get.snackbar(
          '수정 실패',
          '농지 정보 수정 중 오류가 발생했습니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
        return false;
      }
    } catch (e) {
      print('Error updating field: $e');
      isLoading.value = false;
      Get.snackbar(
        '오류',
        '농지 정보 수정 중 오류가 발생했습니다: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return false;
    }
  }

  // 농지 삭제
  Future<bool> deleteField(String fieldId) async {
    try {
      isLoading.value = true;

      bool success = await _fieldService.deleteField(fieldId);

      isLoading.value = false;

      if (success) {
        // 성공 메시지
        Get.snackbar(
          '삭제 완료',
          '농지 정보가 성공적으로 삭제되었습니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );

        // 농지 목록 새로고침
        await loadFields();

        // 선택된 농지 초기화
        selectedField.value = null;

        return true;
      } else {
        Get.snackbar(
          '삭제 실패',
          '농지 정보 삭제 중 오류가 발생했습니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
        return false;
      }
    } catch (e) {
      print('Error deleting field: $e');
      isLoading.value = false;
      Get.snackbar(
        '오류',
        '농지 삭제 중 오류가 발생했습니다: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return false;
    }
  }

  // 작업 단계 변경
  Future<bool> updateStage(String fieldId, String newStage) async {
    try {
      isLoading.value = true;

      bool success = await _fieldService.updateFieldStage(fieldId, newStage);

      isLoading.value = false;

      if (success) {
        // 성공 메시지
        Get.snackbar(
          '단계 변경 완료',
          '작업 단계가 "$newStage"로 변경되었습니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );

        // 농지 목록 새로고침
        await loadFields();

        // 선택된 농지 정보 업데이트
        await selectField(fieldId);

        return true;
      } else {
        Get.snackbar(
          '단계 변경 실패',
          '작업 단계 변경 중 오류가 발생했습니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
        return false;
      }
    } catch (e) {
      print('Error updating stage: $e');
      isLoading.value = false;
      Get.snackbar(
        '오류',
        '작업 단계 변경 중 오류가 발생했습니다: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return false;
    }
  }

  // 작물 종류 추가
  void addCropType(String newCropType) {
    if (newCropType.isEmpty) return;

    if (!cropTypes.contains(newCropType)) {
      cropTypes.add(newCropType);
      cropTypes.sort(); // 정렬
    }

    selectedCropType.value = newCropType;
  }

  // 폼 초기화
  void resetForm() {
    // Non-reactive variables can be updated immediately
    addressController.clear();
    detailAddressController.clear();
    areaController.clear();
    cropTypeController.clear();
    memoController.clear();

    // Reactive variables are initialized in the next microtask
    Future.microtask(() {
      selectedFarm.value = null;
      selectedAreaUnit.value = '평';
      selectedHarvestDate.value = null;
      // UI update notification if needed
      update();
    });
  }

  // 수정을 위한 폼 데이터 설정
  void setFormDataForEdit(FieldModel field) async {
    try {
      // 농가 정보 로드
      farm_model.FarmModel? farm = await _farmService.getFarm(field.farmerId);
      selectedFarm.value = farm;

      // 주소 정보 설정
      addressController.text = field.address.full;
      detailAddressController.text = field.address.detail ?? '';

      // 면적 정보 설정
      areaController.text = field.area.value.toString();
      selectedAreaUnit.value = field.area.unit;

      // 작물 및 기타 정보
      cropTypeController.text = field.cropType;
      selectedHarvestDate.value = field.estimatedHarvestDate;
      memoController.text = field.memo ?? '';
    } catch (e) {
      print('Error setting form data for edit: $e');
      Get.snackbar(
        '오류',
        '농지 정보를 불러오는 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  // 면적 단위 변환 함수
  double convertArea(double value, String fromUnit, String toUnit) {
    // 평 -> 제곱미터 -> 헥타르 변환 계수
    const double pyeongToSqMeter = 3.305785;
    const double sqMeterToHectare = 0.0001;

    // 모든 단위를 제곱미터로 변환
    double sqMeters;
    switch (fromUnit) {
      case '평':
        sqMeters = value * pyeongToSqMeter;
        break;
      case '제곱미터':
        sqMeters = value;
        break;
      case '헥타르':
        sqMeters = value / sqMeterToHectare;
        break;
      default:
        return value; // 알 수 없는 단위는 변환하지 않음
    }

    // 제곱미터에서 목표 단위로 변환
    switch (toUnit) {
      case '평':
        return sqMeters / pyeongToSqMeter;
      case '제곱미터':
        return sqMeters;
      case '헥타르':
        return sqMeters * sqMeterToHectare;
      default:
        return value; // 알 수 없는 단위는 변환하지 않음
    }
  }
}
