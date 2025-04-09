// lib/controllers/contract_controller.dart
import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/contract_model.dart';
import '../services/contract_service.dart';
import '../models/farm_model.dart';
import '../models/field_model.dart';
import 'auth_controller.dart';
import 'farm_controller.dart';
import 'field_controller.dart';

class ContractController extends GetxController {
  final ContractService _contractService = ContractService();
  final AuthController _authController = Get.find<AuthController>();
  final FarmController _farmController = Get.find<FarmController>();
  final FieldController _fieldController = Get.find<FieldController>();

  RxBool isLoading = false.obs;
  RxList<ContractModel> contracts = <ContractModel>[].obs;
  RxList<ContractModel> filteredContracts = <ContractModel>[].obs;
  Rx<ContractModel?> selectedContract = Rx<ContractModel?>(null);

  // 필터링 상태
  RxString searchQuery = ''.obs;
  RxString filterType =
      'all'.obs; // 'all', 'farmerId', 'contractType', 'contractStatus'
  RxString selectedContractType = ''.obs;
  RxString selectedContractStatus = ''.obs;
  RxString selectedFarmerId = ''.obs;

  // 계약 유형 및 상태 목록
  RxList<String> contractTypes = <String>[].obs;
  RxList<String> contractStatuses =
      <String>['pending', 'active', 'completed', 'cancelled'].obs;

  // 폼 컨트롤러 - 계약 기본 정보
  Rx<FarmModel?> selectedFarm = Rx<FarmModel?>(null);
  RxList<FieldModel> selectedFields = <FieldModel>[].obs;
  TextEditingController contractNumberController = TextEditingController();
  Rx<DateTime> contractDateController = DateTime.now().obs;
  RxString selectedContractTypeValue = '일반'.obs;

  // 폼 컨트롤러 - 금액 정보
  TextEditingController totalAmountController = TextEditingController();

  // 계약금 정보
  TextEditingController downPaymentAmountController = TextEditingController();
  Rx<DateTime?> downPaymentDueDateController = Rx<DateTime?>(null);

  // 중도금 정보 (여러 회차 가능)
  RxList<IntermediatePaymentForm> intermediatePayments =
      <IntermediatePaymentForm>[].obs;

  // 잔금 정보
  TextEditingController finalPaymentAmountController = TextEditingController();
  Rx<DateTime?> finalPaymentDueDateController = Rx<DateTime?>(null);

  // 계약 세부사항
  Rx<DateTime?> harvestPeriodStartController = Rx<DateTime?>(null);
  Rx<DateTime?> harvestPeriodEndController = Rx<DateTime?>(null);
  TextEditingController pricePerUnitController = TextEditingController();
  RxString unitTypeController = 'kg'.obs;
  TextEditingController estimatedQuantityController = TextEditingController();
  TextEditingController specialTermsController = TextEditingController();
  TextEditingController qualityStandardsController = TextEditingController();

  // 메모
  TextEditingController memoController = TextEditingController();

  // 첨부 파일
  RxList<AttachmentItem> attachmentFiles = <AttachmentItem>[].obs;

  // 납부 처리 컨트롤러
  Rx<DateTime> paymentDateController = DateTime.now().obs;
  TextEditingController paymentAmountController = TextEditingController();
  Rx<File?> receiptImageFile = Rx<File?>(null);

  @override
  void onInit() {
    super.onInit();
    loadContracts();
    loadContractTypes();

    // 반응형 리스너는 onReady()에서 등록
  }

  @override
  void onReady() {
    super.onReady();
    // 화면 빌드가 완료된 후에 반응형 리스너를 등록
    ever(searchQuery, (_) => filterContracts());
    ever(filterType, (_) => filterContracts());
    ever(selectedContractType, (_) => filterContracts());
    ever(selectedContractStatus, (_) => filterContracts());
    ever(selectedFarmerId, (_) => filterContracts());

    // 총 금액 -> 계약금 자동 계산
    ever(totalAmountController.obs, (_) {
      if (totalAmountController.text.isNotEmpty) {
        try {
          double total = double.parse(totalAmountController.text);
          // 계약금 기본값: 총액의 10%
          downPaymentAmountController.text = (total * 0.1).toStringAsFixed(0);
          // 잔금 기본값: 총액의 20%
          finalPaymentAmountController.text = (total * 0.2).toStringAsFixed(0);

          // 중도금 자동 계산 필요 시 활성화
          /* if (intermediatePayments.isNotEmpty) {
            double intermediateTotal = total * 0.7; // 총액의 70%
            double perPayment = intermediateTotal / intermediatePayments.length;
            for (var i = 0; i < intermediatePayments.length; i++) {
              intermediatePayments[i].amountController.text = perPayment.toStringAsFixed(0);
            }
          } */
        } catch (e) {
          print('Error calculating payment amounts: $e');
        }
      }
    });
  }

  @override
  void onClose() {
    // 컨트롤러 해제
    contractNumberController.dispose();
    totalAmountController.dispose();
    downPaymentAmountController.dispose();
    for (var payment in intermediatePayments) {
      payment.amountController.dispose();
    }
    finalPaymentAmountController.dispose();
    pricePerUnitController.dispose();
    estimatedQuantityController.dispose();
    specialTermsController.dispose();
    qualityStandardsController.dispose();
    memoController.dispose();
    paymentAmountController.dispose();
    super.onClose();
  }

  // 모든 계약 로드
  Future<void> loadContracts() async {
    try {
      isLoading.value = true;

      // 계약 데이터를 스트림으로 가져옴
      var contractsStream = _contractService.getContracts();
      contractsStream.listen((contractsList) {
        contracts.value = contractsList;
        filterContracts(); // 필터링 적용
        isLoading.value = false;
      }, onError: (error) {
        print('loadContracts 에러: $error');
        isLoading.value = false;
        Get.snackbar(
          '오류',
          '계약 목록을 불러오는 중 오류가 발생했습니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      });
    } catch (e) {
      print('Unexpected error in loadContracts: $e');
      isLoading.value = false;
      Get.snackbar(
        '오류',
        '계약 목록을 불러오는 중 예기치 않은 오류가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  // 특정 농가의 계약 로드
  Future<void> loadContractsByFarm(String farmId) async {
    try {
      isLoading.value = true;

      // 농가별 계약 데이터를 스트림으로 가져옴
      var contractsStream = _contractService.getContractsByFarm(farmId);
      contractsStream.listen((contractsList) {
        contracts.value = contractsList;
        filterContracts(); // 필터링 적용
        isLoading.value = false;
      }, onError: (error) {
        print('loadContractsByFarm 에러: $error');
        isLoading.value = false;
        Get.snackbar(
          '오류',
          '농가별 계약 목록을 불러오는 중 오류가 발생했습니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      });
    } catch (e) {
      print('Unexpected error in loadContractsByFarm: $e');
      isLoading.value = false;
    }
  }

  // 계약 유형 목록 로드
  Future<void> loadContractTypes() async {
    try {
      List<String> types = await _contractService.getContractTypes();
      contractTypes.value = types;
    } catch (e) {
      print('Error loading contract types: $e');
    }
  }

  // 계약 필터링
  void filterContracts() {
    try {
      List<ContractModel> result = [];
      if (contracts.isNotEmpty) {
        result = List.from(contracts);

        // 검색어 필터링
        if (searchQuery.isNotEmpty) {
          switch (filterType.value) {
            case 'contractNumber':
              result = result
                  .where((contract) => contract.contractNumber
                      .toLowerCase()
                      .contains(searchQuery.value.toLowerCase()))
                  .toList();
              break;
            default: // 'all'
              result = result
                  .where((contract) =>
                      contract.contractNumber
                          .toLowerCase()
                          .contains(searchQuery.value.toLowerCase()) ||
                      contract.contractType
                          .toLowerCase()
                          .contains(searchQuery.value.toLowerCase()))
                  .toList();
          }
        }

        // 계약 유형 필터링
        if (selectedContractType.isNotEmpty) {
          result = result
              .where((contract) =>
                  contract.contractType == selectedContractType.value)
              .toList();
        }

        // 계약 상태 필터링
        if (selectedContractStatus.isNotEmpty) {
          result = result
              .where((contract) =>
                  contract.contractStatus == selectedContractStatus.value)
              .toList();
        }

        // 농가 ID 필터링
        if (selectedFarmerId.isNotEmpty) {
          result = result
              .where((contract) => contract.farmerId == selectedFarmerId.value)
              .toList();
        }
      }
      // 다음 프레임에 결과 업데이트하여 build 중 상태 업데이트 문제 해결
      Future.microtask(() {
        filteredContracts.value = result;
      });
    } catch (e) {
      print('Error filtering contracts: $e');
      Get.snackbar(
        '오류',
        '계약 필터링 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  // 계약 선택
  Future<void> selectContract(String contractId) async {
    try {
      isLoading.value = true;
      ContractModel? contract = await _contractService.getContract(contractId);
      selectedContract.value = contract;
      isLoading.value = false;
    } catch (e) {
      print('Error selecting contract: $e');
      isLoading.value = false;
      Get.snackbar(
        '오류',
        '계약 정보를 불러오는 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  // 중도금 폼 항목 추가
  void addIntermediatePaymentForm() {
    try {
      int nextInstallmentNumber = intermediatePayments.length + 1;

      intermediatePayments.add(IntermediatePaymentForm(
        installmentNumber: nextInstallmentNumber,
        amountController: TextEditingController(),
        dueDate: null,
      ));

      // 금액 자동 계산 (필요 시)
      if (totalAmountController.text.isNotEmpty) {
        try {
          double total = double.parse(totalAmountController.text);
          double downPayment = double.parse(downPaymentAmountController.text);
          double finalPayment = double.parse(finalPaymentAmountController.text);

          double intermediateTotal = total - downPayment - finalPayment;
          double perPayment = intermediateTotal / intermediatePayments.length;

          for (var payment in intermediatePayments) {
            payment.amountController.text = perPayment.toStringAsFixed(0);
          }
        } catch (e) {
          print('Error calculating intermediate payments: $e');
        }
      }
    } catch (e) {
      print('Error adding intermediate payment form: $e');
    }
  }

  // 중도금 폼 항목 제거
  void removeIntermediatePaymentForm(int index) {
    try {
      if (index >= 0 && index < intermediatePayments.length) {
        // 컨트롤러 해제
        intermediatePayments[index].amountController.dispose();

        // 항목 제거
        intermediatePayments.removeAt(index);

        // 회차 번호 재정렬
        for (int i = 0; i < intermediatePayments.length; i++) {
          intermediatePayments[i].installmentNumber = i + 1;
        }

        // 금액 재계산 (필요 시)
        if (totalAmountController.text.isNotEmpty &&
            intermediatePayments.isNotEmpty) {
          try {
            double total = double.parse(totalAmountController.text);
            double downPayment = double.parse(downPaymentAmountController.text);
            double finalPayment =
                double.parse(finalPaymentAmountController.text);

            double intermediateTotal = total - downPayment - finalPayment;
            double perPayment = intermediateTotal / intermediatePayments.length;

            for (var payment in intermediatePayments) {
              payment.amountController.text = perPayment.toStringAsFixed(0);
            }
          } catch (e) {
            print('Error recalculating intermediate payments: $e');
          }
        }
      }
    } catch (e) {
      print('Error removing intermediate payment form: $e');
    }
  }

  // 첨부 파일 선택
  Future<void> pickAttachmentFile() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        attachmentFiles.add(AttachmentItem(
          file: File(pickedFile.path),
          name: pickedFile.name,
          type: 'image/jpeg', // 파일 타입 자동 감지 하면 좋음
        ));
      }
    } catch (e) {
      print('Error picking attachment file: $e');
      Get.snackbar(
        '오류',
        '첨부 파일 선택 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  // 첨부 파일 제거
  void removeAttachmentFile(int index) {
    try {
      if (index >= 0 && index < attachmentFiles.length) {
        attachmentFiles.removeAt(index);
      }
    } catch (e) {
      print('Error removing attachment file: $e');
    }
  }

  // 영수증 이미지 선택
  Future<void> pickReceiptImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        receiptImageFile.value = File(pickedFile.path);
      }
    } catch (e) {
      print('Error picking receipt image: $e');
      Get.snackbar(
        '오류',
        '영수증 이미지 선택 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  // 계약 생성
  Future<bool> createContract() async {
    try {
      isLoading.value = true;

      // 기본 필수 필드 검증
      if (selectedFarm.value == null ||
          selectedFields.isEmpty ||
          totalAmountController.text.isEmpty ||
          downPaymentAmountController.text.isEmpty ||
          finalPaymentAmountController.text.isEmpty ||
          pricePerUnitController.text.isEmpty ||
          estimatedQuantityController.text.isEmpty) {
        Get.snackbar(
          '입력 오류',
          '필수 항목을 모두 입력해주세요.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
        isLoading.value = false;
        return false;
      }

      // 중도금 검증
      for (var payment in intermediatePayments) {
        if (payment.amountController.text.isEmpty || payment.dueDate == null) {
          Get.snackbar(
            '입력 오류',
            '모든 중도금 정보를 입력해주세요.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
          isLoading.value = false;
          return false;
        }
      }

      // 농지 ID 목록
      List<String> fieldIds = selectedFields.map((field) => field.id).toList();

      // lib/controllers/contract_controller.dart (계속)
      // 계약금 정보
      PaymentInfo downPayment = PaymentInfo(
        amount: double.parse(downPaymentAmountController.text),
        dueDate: downPaymentDueDateController.value,
        status: 'pending',
      );

      // 중도금 정보
      List<IntermediatePayment> intermediatePaymentsList = [];
      for (var payment in intermediatePayments) {
        intermediatePaymentsList.add(IntermediatePayment(
          installmentNumber: payment.installmentNumber,
          amount: double.parse(payment.amountController.text),
          dueDate: payment.dueDate,
          status: 'pending',
        ));
      }

      // 잔금 정보
      PaymentInfo finalPayment = PaymentInfo(
        amount: double.parse(finalPaymentAmountController.text),
        dueDate: finalPaymentDueDateController.value,
        status: 'pending',
      );

      // 계약 세부사항
      ContractDetails contractDetails = ContractDetails(
        harvestPeriodStart: harvestPeriodStartController.value,
        harvestPeriodEnd: harvestPeriodEndController.value,
        pricePerUnit: double.parse(pricePerUnitController.text),
        unitType: unitTypeController.value,
        estimatedQuantity: double.parse(estimatedQuantityController.text),
        specialTerms: specialTermsController.text.isNotEmpty
            ? specialTermsController.text
            : null,
        qualityStandards: qualityStandardsController.text.isNotEmpty
            ? qualityStandardsController.text
            : null,
      );

      // 첨부 파일 업로드는 계약 생성 후에 처리

      String? contractId = await _contractService.createContract(
        farmerId: selectedFarm.value!.id,
        fieldIds: fieldIds,
        contractDate: contractDateController.value,
        contractType: selectedContractTypeValue.value,
        totalAmount: double.parse(totalAmountController.text),
        downPayment: downPayment,
        intermediatePayments: intermediatePaymentsList,
        finalPayment: finalPayment,
        contractDetails: contractDetails,
        memo: memoController.text.isNotEmpty ? memoController.text : null,
      );

      if (contractId != null) {
        // 첨부 파일 업로드
        for (var attachment in attachmentFiles) {
          await _contractService.uploadAttachment(
            contractId,
            attachment.file,
            attachment.name,
            attachment.type,
          );
        }

        Get.snackbar(
          '등록 완료',
          '계약 정보가 성공적으로 등록되었습니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
        resetForm();
        await loadContracts();
        return true;
      } else {
        Get.snackbar(
          '등록 실패',
          '계약 정보 등록 중 오류가 발생했습니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
        return false;
      }
    } catch (e) {
      print('Error creating contract: $e');
      Get.snackbar(
        '오류',
        '계약 등록 중 오류가 발생했습니다: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 납부 처리
  Future<bool> processPayment({
    required String contractId,
    required String paymentType,
    required int installmentNumber,
  }) async {
    try {
      isLoading.value = true;

      // 필수 필드 검증
      if (paymentAmountController.text.isEmpty) {
        Get.snackbar(
          '입력 오류',
          '납부 금액을 입력해주세요.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
        isLoading.value = false;
        return false;
      }

      bool success = await _contractService.processPayment(
        contractId: contractId,
        paymentType: paymentType,
        installmentNumber: installmentNumber,
        paidDate: paymentDateController.value,
        paidAmount: double.parse(paymentAmountController.text),
        receiptImage: receiptImageFile.value,
      );

      if (success) {
        Get.snackbar(
          '납부 처리 완료',
          '납부 정보가 성공적으로 등록되었습니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
        paymentAmountController.clear();
        receiptImageFile.value = null;
        await selectContract(contractId); // 계약 정보 새로고침
        return true;
      } else {
        Get.snackbar(
          '납부 처리 실패',
          '납부 정보 등록 중 오류가 발생했습니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
        return false;
      }
    } catch (e) {
      print('Error processing payment: $e');
      Get.snackbar(
        '오류',
        '납부 처리 중 오류가 발생했습니다: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 계약 상태 변경
  Future<bool> updateContractStatus(String contractId, String newStatus) async {
    try {
      isLoading.value = true;
      bool success =
          await _contractService.updateContractStatus(contractId, newStatus);

      if (success) {
        Get.snackbar(
          '상태 변경 완료',
          '계약 상태가 성공적으로 변경되었습니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
        await selectContract(contractId); // 계약 정보 새로고침
        return true;
      } else {
        Get.snackbar(
          '상태 변경 실패',
          '계약 상태 변경 중 오류가 발생했습니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
        return false;
      }
    } catch (e) {
      print('Error updating contract status: $e');
      Get.snackbar(
        '오류',
        '계약 상태 변경 중 오류가 발생했습니다: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 계약 삭제
  Future<bool> deleteContract(String contractId) async {
    try {
      isLoading.value = true;
      bool success = await _contractService.deleteContract(contractId);

      if (success) {
        Get.snackbar(
          '삭제 완료',
          '계약 정보가 성공적으로 삭제되었습니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
        selectedContract.value = null;
        await loadContracts();
        return true;
      } else {
        Get.snackbar(
          '삭제 실패',
          '계약 정보 삭제 중 오류가 발생했습니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
        return false;
      }
    } catch (e) {
      print('Error deleting contract: $e');
      Get.snackbar(
        '오류',
        '계약 삭제 중 오류가 발생했습니다: $e',
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
    contractNumberController.clear();
    totalAmountController.clear();
    downPaymentAmountController.clear();
    finalPaymentAmountController.clear();
    pricePerUnitController.clear();
    estimatedQuantityController.clear();
    specialTermsController.clear();
    qualityStandardsController.clear();
    memoController.clear();

    // 중도금 컨트롤러 해제
    for (var payment in intermediatePayments) {
      payment.amountController.dispose();
    }

    // 반응형 변수는 다음 마이크로태스크에서 초기화
    Future.microtask(() {
      selectedFarm.value = null;
      selectedFields.clear();
      contractDateController.value = DateTime.now();
      selectedContractTypeValue.value = '일반';
      downPaymentDueDateController.value = null;
      intermediatePayments.clear();
      finalPaymentDueDateController.value = null;
      harvestPeriodStartController.value = null;
      harvestPeriodEndController.value = null;
      unitTypeController.value = 'kg';
      attachmentFiles.clear();
      // UI 업데이트 통지
      update();
    });
  }

  // 단위 문자열을 위한 도우미 함수
  String formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'ko_KR');
    return formatter.format(amount);
  }

  // 상태 라벨 변환 도우미 함수
  String getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return '계약예정';
      case 'active':
        return '계약중';
      case 'completed':
        return '완료';
      case 'cancelled':
        return '취소됨';
      default:
        return status;
    }
  }

  // 납부 상태 라벨 변환 도우미 함수
  String getPaymentStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return '납부예정';
      case 'paid':
        return '납부완료';
      case 'overdue':
        return '납부지연';
      default:
        return status;
    }
  }

  // 상태에 따른 색상 반환 도우미 함수
  Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.blue;
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // 납부 상태에 따른 색상 반환 도우미 함수
  Color getPaymentStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.blue;
      case 'paid':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // 납부 예정일 자동 체크 및 상태 업데이트
  void checkDuePayments() {
    final now = DateTime.now();

    for (var contract in contracts) {
      bool needsUpdate = false;
      String contractStatus = contract.contractStatus;

      // 계약금 체크
      if (contract.downPayment.status == 'pending' &&
          contract.downPayment.dueDate != null &&
          contract.downPayment.dueDate!.isBefore(now)) {
        needsUpdate = true;
      }

      // 중도금 체크
      for (var payment in contract.intermediatePayments) {
        if (payment.status == 'pending' &&
            payment.dueDate != null &&
            payment.dueDate!.isBefore(now)) {
          needsUpdate = true;
          break;
        }
      }

      // 잔금 체크
      if (contract.finalPayment.status == 'pending' &&
          contract.finalPayment.dueDate != null &&
          contract.finalPayment.dueDate!.isBefore(now)) {
        needsUpdate = true;
      }

      // 오늘 기준으로 납부가 지연된 계약이 있다면 알림 표시
      if (needsUpdate) {
        Get.snackbar(
          '납부 미완료 계약 알림',
          '계약번호 ${contract.contractNumber}의 납부 예정일이 지났습니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.yellow.shade100,
          colorText: Colors.orange.shade800,
          duration: const Duration(seconds: 5),
        );
      }
    }
  }
}

// 중도금 폼 항목 클래스
class IntermediatePaymentForm {
  int installmentNumber;
  TextEditingController amountController;
  DateTime? dueDate;

  IntermediatePaymentForm({
    required this.installmentNumber,
    required this.amountController,
    this.dueDate,
  });
}

// 첨부 파일 항목 클래스
class AttachmentItem {
  File file;
  String name;
  String type;

  AttachmentItem({
    required this.file,
    required this.name,
    required this.type,
  });
}
