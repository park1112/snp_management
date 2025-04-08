import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/farm_model.dart';
import '../services/farm_service.dart';

class FarmController extends GetxController {
  final FarmService _farmService = FarmService();

  RxBool isLoading = false.obs;
  RxList<FarmModel> farms = <FarmModel>[].obs;
  RxList<FarmModel> filteredFarms = <FarmModel>[].obs;
  Rx<FarmModel?> selectedFarm = Rx<FarmModel?>(null);

  // 검색 및 필터링 상태
  RxString searchQuery = ''.obs;
  RxString filterType = 'all'.obs; // 'all', 'name', 'phone', 'subdistrict'
  RxString selectedSubdistrict = ''.obs;
  RxString selectedPaymentGroup = ''.obs;

  // 면단위 및 결제소속 목록
  RxList<String> subdistricts = <String>[].obs;
  RxList<String> paymentGroups = <String>[].obs;

  // 폼 컨트롤러
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController personalIdController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController detailAddressController = TextEditingController();
  TextEditingController accountNumberController = TextEditingController();
  TextEditingController accountHolderController = TextEditingController();
  TextEditingController memoController = TextEditingController();
  TextEditingController bankNameController = TextEditingController();

  // 은행 선택
  RxString selectedBank = ''.obs;
  final List<String> banks = [
    '국민은행',
    '신한은행',
    '우리은행',
    '하나은행',
    '기업은행',
    '농협은행',
    '수협은행',
    '부산은행',
    '대구은행',
    '광주은행',
    '전북은행',
    '제주은행',
    '카카오뱅크',
    '케이뱅크',
    '토스뱅크'
  ];

  @override
  void onInit() {
    super.onInit();
    loadFarms();
    loadSubdistricts();
    loadPaymentGroups();
    // 반응형 리스너는 onReady()에서 등록
  }

  @override
  void onReady() {
    super.onReady();
    // 화면 빌드가 완료된 후에 반응형 리스너를 등록
    ever(searchQuery, (_) => filterFarms());
    ever(filterType, (_) => filterFarms());
    ever(selectedSubdistrict, (_) => filterFarms());
    ever(selectedPaymentGroup, (_) => filterFarms());
  }

  @override
  void onClose() {
    // 컨트롤러 해제
    nameController.dispose();
    phoneController.dispose();
    personalIdController.dispose();
    addressController.dispose();
    detailAddressController.dispose();
    accountNumberController.dispose();
    accountHolderController.dispose();
    memoController.dispose();
    bankNameController.dispose();
    super.onClose();
  }

  // 모든 농가 로드
  Future<void> loadFarms() async {
    try {
      isLoading.value = true;

      // 농가 데이터를 스트림으로 가져옴
      var farmsStream = _farmService.getFarms();
      farmsStream.listen((farmsList) {
        try {
          farms.value = farmsList;
          filterFarms(); // 필터링 적용
        } catch (e, stackTrace) {
          debugPrint('Stream listen 중 필터링 오류: $e\n$stackTrace');
          Get.snackbar(
            '오류',
            '농가 데이터를 처리하는 중 문제가 발생했습니다.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
        } finally {
          isLoading.value = false;
        }
      }, onError: (error) {
        debugPrint('loadFarms 에러: $error');
        isLoading.value = false;
        Get.snackbar(
          '오류',
          '농가 목록을 불러오는 중 오류가 발생했습니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      });
    } catch (e, stackTrace) {
      debugPrint('Unexpected error in loadFarms: $e\n$stackTrace');
      isLoading.value = false;
      Get.snackbar(
        '오류',
        '농가 목록을 불러오는 중 예기치 않은 오류가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  // 농가 필터링
  void filterFarms() {
    try {
      List<FarmModel> result = [];
      if (farms.isNotEmpty) {
        result = List.from(farms);

        // 검색어 필터링
        if (searchQuery.isNotEmpty) {
          switch (filterType.value) {
            case 'name':
              result = result
                  .where((farm) => farm.name
                      .toLowerCase()
                      .contains(searchQuery.value.toLowerCase()))
                  .toList();
              break;
            case 'phone':
              result = result
                  .where((farm) => farm.phoneNumber.contains(searchQuery.value))
                  .toList();
              break;
            default: // 'all'
              result = result
                  .where((farm) =>
                      farm.name
                          .toLowerCase()
                          .contains(searchQuery.value.toLowerCase()) ||
                      farm.phoneNumber.contains(searchQuery.value))
                  .toList();
          }
        }

        // 면단위 필터링
        if (selectedSubdistrict.isNotEmpty) {
          result = result
              .where((farm) => farm.subdistrict == selectedSubdistrict.value)
              .toList();
        }

        // 결제소속 필터링
        if (selectedPaymentGroup.isNotEmpty) {
          result = result
              .where((farm) => farm.paymentGroup == selectedPaymentGroup.value)
              .toList();
        }
      }
      // 다음 프레임에 결과 업데이트하여 build 중 상태 업데이트 문제 해결
      Future.microtask(() {
        filteredFarms.value = result;
      });
    } catch (e, stackTrace) {
      debugPrint('Error filtering farms: $e\n$stackTrace');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          '오류',
          '농가 필터링 중 오류가 발생했습니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      });
    }
  }

  // 면단위 목록 로드
  Future<void> loadSubdistricts() async {
    try {
      List<String> result = await _farmService.getSubdistricts();
      subdistricts.value = result;
    } catch (e, stackTrace) {
      debugPrint('Error loading subdistricts: $e\n$stackTrace');
      Get.snackbar(
        '오류',
        '면단위 목록을 불러오는 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  // 결제소속 목록 로드
  Future<void> loadPaymentGroups() async {
    try {
      List<String> result = await _farmService.getPaymentGroups();
      paymentGroups.value = result;
    } catch (e, stackTrace) {
      debugPrint('Error loading payment groups: $e\n$stackTrace');
      Get.snackbar(
        '오류',
        '결제소속 목록을 불러오는 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  // 농가 선택
  Future<void> selectFarm(String farmId) async {
    try {
      isLoading.value = true;
      FarmModel? farm = await _farmService.getFarm(farmId);
      selectedFarm.value = farm;
    } catch (e, stackTrace) {
      debugPrint('Error selecting farm: $e\n$stackTrace');
      Get.snackbar(
        '오류',
        '농가 정보를 불러오는 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // 농가 등록
  Future<bool> createFarm() async {
    try {
      isLoading.value = true;
      // 기본 필수 필드 검증
      if (nameController.text.trim().isEmpty ||
          phoneController.text.trim().isEmpty ||
          selectedSubdistrict.isEmpty ||
          selectedPaymentGroup.isEmpty) {
        Get.snackbar(
          '입력 오류',
          '이름, 전화번호, 면단위, 결제소속은 필수 입력 항목입니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
        return false;
      }

      // 주소 정보 (선택 사항)
      Address? address;
      if (addressController.text.isNotEmpty) {
        address = Address(
          full: addressController.text.trim(),
          detail: detailAddressController.text.trim(),
          coordinates: null, // 지도에서 좌표 선택 기능 추가 필요
        );
      }

      // 계좌 정보 (선택 사항)
      BankInfo? bankInfo;
      if (selectedBank.isNotEmpty && accountNumberController.text.isNotEmpty) {
        bankInfo = BankInfo(
          bankName: selectedBank.value,
          accountNumber: accountNumberController.text.trim(),
          accountHolder: accountHolderController.text.trim().isNotEmpty
              ? accountHolderController.text.trim()
              : nameController.text.trim(),
        );
      }

      String? farmId = await _farmService.createFarm(
        name: nameController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        subdistrict: selectedSubdistrict.value,
        paymentGroup: selectedPaymentGroup.value,
        personalId: personalIdController.text.trim().isNotEmpty
            ? personalIdController.text.trim()
            : null,
        address: address,
        bankInfo: bankInfo,
        memo: memoController.text.trim().isNotEmpty
            ? memoController.text.trim()
            : null,
      );

      if (farmId != null) {
        Get.snackbar(
          '등록 완료',
          '농가 정보가 성공적으로 등록되었습니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
        resetForm();
        await loadFarms();
        return true;
      } else {
        Get.snackbar(
          '등록 실패',
          '농가 정보 등록 중 오류가 발생했습니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('Error creating farm: $e\n$stackTrace');
      Get.snackbar(
        '오류',
        '농가 등록 중 오류가 발생했습니다: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 농가 정보 수정
  Future<bool> updateFarm(String farmId) async {
    try {
      isLoading.value = true;
      if (nameController.text.trim().isEmpty ||
          phoneController.text.trim().isEmpty ||
          selectedSubdistrict.isEmpty ||
          selectedPaymentGroup.isEmpty) {
        Get.snackbar(
          '입력 오류',
          '이름, 전화번호, 면단위, 결제소속은 필수 입력 항목입니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
        return false;
      }

      Address? address;
      if (addressController.text.isNotEmpty) {
        address = Address(
          full: addressController.text.trim(),
          detail: detailAddressController.text.trim(),
          coordinates: null,
        );
      }

      BankInfo? bankInfo;
      if (selectedBank.isNotEmpty && accountNumberController.text.isNotEmpty) {
        bankInfo = BankInfo(
          bankName: selectedBank.value,
          accountNumber: accountNumberController.text.trim(),
          accountHolder: accountHolderController.text.trim().isNotEmpty
              ? accountHolderController.text.trim()
              : nameController.text.trim(),
        );
      }

      bool success = await _farmService.updateFarm(
        farmId: farmId,
        name: nameController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        subdistrict: selectedSubdistrict.value,
        paymentGroup: selectedPaymentGroup.value,
        personalId: personalIdController.text.trim().isNotEmpty
            ? personalIdController.text.trim()
            : null,
        address: address,
        bankInfo: bankInfo,
        memo: memoController.text.trim().isNotEmpty
            ? memoController.text.trim()
            : null,
      );

      if (success) {
        Get.snackbar(
          '수정 완료',
          '농가 정보가 성공적으로 수정되었습니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
        await loadFarms();
        await selectFarm(farmId);
        return true;
      } else {
        Get.snackbar(
          '수정 실패',
          '농가 정보 수정 중 오류가 발생했습니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('Error updating farm: $e\n$stackTrace');
      Get.snackbar(
        '오류',
        '농가 정보 수정 중 오류가 발생했습니다: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 농가 삭제
  Future<bool> deleteFarm(String farmId) async {
    try {
      isLoading.value = true;
      bool success = await _farmService.deleteFarm(farmId);
      if (success) {
        Get.snackbar(
          '삭제 완료',
          '농가 정보가 성공적으로 삭제되었습니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
        await loadFarms();
        selectedFarm.value = null;
        return true;
      } else {
        Get.snackbar(
          '삭제 실패',
          '농가 정보 삭제 중 오류가 발생했습니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('Error deleting farm: $e\n$stackTrace');
      Get.snackbar(
        '오류',
        '농가 삭제 중 오류가 발생했습니다: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 폼 초기화
  void resetForm() {
    // 컨트롤러는 즉시 초기화 가능
    nameController.clear();
    phoneController.clear();
    personalIdController.clear();
    addressController.clear();
    detailAddressController.clear();
    accountNumberController.clear();
    accountHolderController.clear();
    memoController.clear();

    // 반응형 변수는 다음 마이크로태스크에서 초기화
    Future.microtask(() {
      selectedBank.value = '';
      selectedSubdistrict.value = '';
      selectedPaymentGroup.value = '';
      // UI 업데이트 통지
      update();
    });
  }

  // 수정을 위한 폼 데이터 설정
  void setFormDataForEdit(FarmModel farm) {
    try {
      // 컨트롤러 값 설정
      nameController.text = farm.name;
      phoneController.text = farm.phoneNumber;
      personalIdController.text = farm.personalId ?? '';

      if (farm.address != null) {
        addressController.text = farm.address!.full;
        detailAddressController.text = farm.address!.detail ?? '';
      }

      // 반응형 변수는 다음 마이크로태스크에서 초기화
      Future.microtask(() {
        if (farm.bankInfo != null) {
          selectedBank.value = farm.bankInfo!.bankName;
          accountNumberController.text = farm.bankInfo!.accountNumber;
          accountHolderController.text = farm.bankInfo!.accountHolder;
        }

        memoController.text = farm.memo ?? '';
        selectedSubdistrict.value = farm.subdistrict;
        selectedPaymentGroup.value = farm.paymentGroup;
        // UI 업데이트 통지
        update();
      });
    } catch (e, stackTrace) {
      debugPrint('Error setting form data for edit: $e\n$stackTrace');
      Get.snackbar(
        '오류',
        '폼 데이터를 설정하는 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }
}
