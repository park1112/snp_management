import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/farm_controller.dart';
import '../../config/theme.dart';
import '../../utils/validators.dart';
import '../../utils/formatters.dart';
import '../../utils/custom_loading.dart';

class FarmEditScreen extends StatefulWidget {
  final String farmId;

  const FarmEditScreen({
    Key? key,
    required this.farmId,
  }) : super(key: key);

  @override
  State<FarmEditScreen> createState() => _FarmEditScreenState();
}

class _FarmEditScreenState extends State<FarmEditScreen> {
  final FarmController controller = Get.find<FarmController>();
  final _formKey = GlobalKey<FormState>();

  // 새 결제소속 추가 관련
  final TextEditingController _newPaymentGroupController =
      TextEditingController();
  bool _isAddingNewPaymentGroup = false;

  @override
  void initState() {
    super.initState();
    // 농가 정보가 이미 로드되어 있지 않다면 로드
    if (controller.selectedFarm.value == null ||
        controller.selectedFarm.value!.id != widget.farmId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.selectFarm(widget.farmId);
      });
    }

    // 편집용 폼 데이터 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.selectedFarm.value != null) {
        controller.setFormDataForEdit(controller.selectedFarm.value!);
      }
    });
  }

  @override
  void dispose() {
    _newPaymentGroupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('농가 정보 수정'),
        actions: [
          TextButton(
            onPressed: _submitForm,
            child: const Text(
              '저장',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CustomLoading());
        }

        if (controller.selectedFarm.value == null) {
          return const Center(
            child: Text('농가 정보를 불러올 수 없습니다.'),
          );
        }

        return Form(
          key: _formKey,
          child: _buildFormContent(context),
        );
      }),
    );
  }

  Widget _buildFormContent(BuildContext context) {
    // 화면 너비에 따라 레이아웃 조정
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWideScreen = screenWidth > 800;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isWideScreen ? 800 : double.infinity,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 필수 입력 안내
              _buildSectionHeader('기본 정보 (필수)', true),
              const SizedBox(height: 16),

              // 이름, 전화번호 (한 줄에 배치)
              if (isWideScreen)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildNameField()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildPhoneField()),
                  ],
                )
              else
                Column(
                  children: [
                    _buildNameField(),
                    const SizedBox(height: 16),
                    _buildPhoneField(),
                  ],
                ),
              const SizedBox(height: 16),

              // 면단위, 결제소속 (한 줄에 배치)
              if (isWideScreen)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildSubdistrictField()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildPaymentGroupField()),
                  ],
                )
              else
                Column(
                  children: [
                    _buildSubdistrictField(),
                    const SizedBox(height: 16),
                    _buildPaymentGroupField(),
                  ],
                ),
              const SizedBox(height: 32),

              // 선택 정보 섹션
              _buildSectionHeader('추가 정보 (선택)', false),
              const SizedBox(height: 16),

              // 주민등록번호
              _buildPersonalIdField(),
              const SizedBox(height: 16),

              // 주소 정보
              _buildAddressFields(isWideScreen),
              const SizedBox(height: 16),

              // 계좌 정보
              _buildBankInfoFields(isWideScreen),
              const SizedBox(height: 16),

              // 메모
              _buildMemoField(),
              const SizedBox(height: 32),

              // 등록 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '정보 수정하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // 섹션 헤더 위젯
  Widget _buildSectionHeader(String title, bool isRequired) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        if (isRequired)
          Text(
            ' (*)는 필수 입력 항목입니다',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  // 이름 필드
  Widget _buildNameField() {
    return TextFormField(
      controller: controller.nameController,
      decoration: const InputDecoration(
        labelText: '이름 *',
        hintText: '농가주 이름 또는 농장 이름',
        prefixIcon: Icon(Icons.person),
      ),
      validator: Validators.validateName,
      textInputAction: TextInputAction.next,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  // 전화번호 필드
  Widget _buildPhoneField() {
    return TextFormField(
      controller: controller.phoneController,
      decoration: const InputDecoration(
        labelText: '전화번호 *',
        hintText: '010-0000-0000',
        prefixIcon: Icon(Icons.phone),
      ),
      keyboardType: TextInputType.phone,
      inputFormatters: [
        PhoneNumberInputFormatter(),
        LengthLimitingTextInputFormatter(13), // 하이픈 포함 13자리
      ],
      validator: Validators.validatePhoneNumber,
      textInputAction: TextInputAction.next,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  // 면단위 필드
  Widget _buildSubdistrictField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '면단위 *',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                hintText: '면단위 선택',
                prefixIcon: Icon(Icons.location_on),
              ),
              value: controller.selectedSubdistrict.value.isEmpty
                  ? null
                  : controller.selectedSubdistrict.value,
              items: [
                // 기존 면단위 목록
                ...controller.subdistricts
                    .map((subdistrict) => DropdownMenuItem(
                          value: subdistrict,
                          child: Text(subdistrict),
                        )),
                // 새 면단위 추가 옵션
                if (controller.subdistricts.isNotEmpty)
                  const DropdownMenuItem(
                    value: '_divider_',
                    enabled: false,
                    child: Divider(),
                  ),
                const DropdownMenuItem(
                  value: '_add_new_',
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 16, color: AppTheme.primaryColor),
                      SizedBox(width: 8),
                      Text(
                        '새 면단위 추가',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value == '_add_new_') {
                  _showAddNewSubdistrictDialog();
                } else {
                  controller.selectedSubdistrict.value = value ?? '';
                }
              },
              validator: Validators.validateSubdistrict,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            )),
      ],
    );
  }

  // 새 면단위 추가 다이얼로그
  Future<void> _showAddNewSubdistrictDialog() async {
    final TextEditingController newSubdistrictController =
        TextEditingController();

    try {
      final result = await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('새 면단위 추가'),
            content: TextField(
              controller: newSubdistrictController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '면단위 이름',
                labelText: '면단위',
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  Navigator.pop(context, value);
                }
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () {
                  final value = newSubdistrictController.text.trim();
                  if (value.isNotEmpty) {
                    Navigator.pop(context, value);
                  }
                },
                child: const Text('추가'),
              ),
            ],
          );
        },
      );

      if (result != null && result.isNotEmpty) {
        if (!controller.subdistricts.contains(result)) {
          controller.subdistricts.add(result);
          controller.subdistricts.sort(); // 정렬
        }
        controller.selectedSubdistrict.value = result;
      }
    } finally {
      newSubdistrictController.dispose();
    }
  }

  // 결제소속 필드
  Widget _buildPaymentGroupField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '결제소속 *',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        _isAddingNewPaymentGroup
            ? _buildNewPaymentGroupInput()
            : Obx(() => DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    hintText: '결제소속 선택',
                    prefixIcon: Icon(Icons.account_balance),
                  ),
                  value: controller.selectedPaymentGroup.value.isEmpty
                      ? null
                      : controller.selectedPaymentGroup.value,
                  items: [
                    // 기존 결제소속 목록
                    ...controller.paymentGroups.map((group) => DropdownMenuItem(
                          value: group,
                          child: Text(group),
                        )),
                    // 새 결제소속 추가 옵션
                    if (controller.paymentGroups.isNotEmpty)
                      const DropdownMenuItem(
                        value: '_divider_',
                        enabled: false,
                        child: Divider(),
                      ),
                    const DropdownMenuItem(
                      value: '_add_new_',
                      child: Row(
                        children: [
                          Icon(Icons.add,
                              size: 16, color: AppTheme.primaryColor),
                          SizedBox(width: 8),
                          Text(
                            '새 결제소속 추가',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == '_add_new_') {
                      setState(() {
                        _isAddingNewPaymentGroup = true;
                      });
                    } else {
                      controller.selectedPaymentGroup.value = value ?? '';
                    }
                  },
                  validator: Validators.validatePaymentGroup,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                )),
      ],
    );
  }

  // 새 결제소속 입력 필드
  Widget _buildNewPaymentGroupInput() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _newPaymentGroupController,
            decoration: const InputDecoration(
              hintText: '새 결제소속 이름',
              prefixIcon: Icon(Icons.account_balance),
            ),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _addNewPaymentGroup(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.check),
          onPressed: _addNewPaymentGroup,
          color: AppTheme.primaryColor,
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              _isAddingNewPaymentGroup = false;
              _newPaymentGroupController.clear();
            });
          },
          color: Colors.red,
        ),
      ],
    );
  }

  // 새 결제소속 추가 처리
  void _addNewPaymentGroup() {
    final String newGroup = _newPaymentGroupController.text.trim();
    if (newGroup.isEmpty) return;

    if (!controller.paymentGroups.contains(newGroup)) {
      controller.paymentGroups.add(newGroup);
      controller.paymentGroups.sort(); // 정렬
    }

    controller.selectedPaymentGroup.value = newGroup;
    setState(() {
      _isAddingNewPaymentGroup = false;
      _newPaymentGroupController.clear();
    });
  }

  // 주민등록번호 필드
  Widget _buildPersonalIdField() {
    return TextFormField(
      controller: controller.personalIdController,
      decoration: const InputDecoration(
        labelText: '주민등록번호',
        hintText: '000000-0000000',
        prefixIcon: Icon(Icons.badge),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        PersonalIdInputFormatter(),
        LengthLimitingTextInputFormatter(14), // 하이픈 포함 14자리
      ],
      validator: Validators.validatePersonalId,
      textInputAction: TextInputAction.next,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  // 주소 필드
  Widget _buildAddressFields(bool isWideScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: controller.addressController,
                decoration: const InputDecoration(
                  labelText: '주소',
                  hintText: '주소 검색',
                  prefixIcon: Icon(Icons.home),
                ),
                readOnly: true,
                onTap: _searchAddress,
                validator: Validators.validateAddress,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _searchAddress,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                minimumSize: const Size(0, 56),
              ),
              child: const Text('주소 검색'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controller.detailAddressController,
          decoration: const InputDecoration(
            labelText: '상세주소',
            hintText: '상세주소 입력',
            prefixIcon: Icon(Icons.location_city),
          ),
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }

  // 주소 검색 함수
  Future<void> _searchAddress() async {
    // TODO: 주소 검색 API 연동
    // 임시 구현: 주소 선택 다이얼로그 표시
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('주소 검색'),
          content: const Text('주소 검색 API 연동이 필요합니다.\n현재는 테스트용 주소만 제공합니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                controller.addressController.text = '경기도 수원시 영통구 월드컵로 206';
                Navigator.pop(context);
              },
              child: const Text('테스트 주소 사용'),
            ),
          ],
        );
      },
    );
  }

  // 계좌 정보 필드
  Widget _buildBankInfoFields(bool isWideScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: controller.bankNameController,
                decoration: const InputDecoration(
                  labelText: '은행',
                  hintText: '은행 선택',
                  prefixIcon: Icon(Icons.account_balance),
                ),
                validator: Validators.validateBankName,
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 메모 필드
  Widget _buildMemoField() {
    return TextFormField(
      controller: controller.memoController,
      decoration: const InputDecoration(
        labelText: '메모',
        prefixIcon: Icon(Icons.note),
        hintText: '특이사항이나 기타 정보를 입력하세요',
      ),
      maxLines: 3,
      textInputAction: TextInputAction.done,
    );
  }

  // 폼 제출 및 데이터 저장
  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      // 키보드 닫기
      FocusScope.of(context).unfocus();

      // 로딩 다이얼로그 표시
      Get.dialog(
        const Center(child: CustomLoading()),
        barrierDismissible: false,
      );

      // 농가 정보 업데이트
      bool success = await controller.updateFarm(widget.farmId);

      // 로딩 다이얼로그 닫기
      Get.back();

      if (success) {
        Get.back(); // 에딧 화면 닫기
        Get.snackbar(
          '성공',
          '농가 정보가 성공적으로 수정되었습니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
      } else {
        Get.snackbar(
          '오류',
          '농가 정보 수정에 실패했습니다. 다시 시도해주세요.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      }
    } else {
      // 폼 유효성 검사 실패 메시지
      Get.snackbar(
        '입력 오류',
        '필수 항목을 모두 입력해주세요',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        margin: const EdgeInsets.all(16),
      );
    }
  }
}

// 전화번호 포맷터
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 구현 생략 - Formatters 클래스에 포함됨
    return newValue;
  }
}

// 주민등록번호 포맷터
class PersonalIdFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 구현 생략 - Formatters 클래스에 포함됨
    return newValue;
  }
}
