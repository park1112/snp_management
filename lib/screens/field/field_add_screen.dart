import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/field_controller.dart';
import '../../controllers/farm_controller.dart';
import '../../config/theme.dart';
import '../../utils/validators.dart';
import '../../utils/custom_loading.dart';
import '../../models/farm_model.dart';

class FieldAddScreen extends StatefulWidget {
  final String? initialFarmId; // 특정 농가의 농지 추가 시 사용

  const FieldAddScreen({
    Key? key,
    this.initialFarmId,
  }) : super(key: key);

  @override
  State<FieldAddScreen> createState() => _FieldAddScreenState();
}

class _FieldAddScreenState extends State<FieldAddScreen> {
  final FieldController controller = Get.find<FieldController>();
  final FarmController farmController = Get.find<FarmController>();
  final _formKey = GlobalKey<FormState>();

  // 작물 종류 입력 관련
  final TextEditingController _newCropTypeController = TextEditingController();
  bool _isAddingNewCropType = false;

  // 단계 상태
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    controller.resetForm();

    if (widget.initialFarmId != null && widget.initialFarmId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await farmController.selectFarm(widget.initialFarmId!);
        if (farmController.selectedFarm.value != null) {
          controller.selectedFarm.value = farmController.selectedFarm.value;
        }
      });
    }
  }

  @override
  void dispose() {
    _newCropTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('농지 등록'),
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

    return isWideScreen ? _buildWideScreenForm() : _buildMobileForm();
  }

  // 태블릿/데스크톱용 폼
  Widget _buildWideScreenForm() {
    return Stepper(
      currentStep: _currentStep,
      onStepContinue: () {
        if (_currentStep < 2) {
          // 첫 번째 단계의 유효성 검사
          if (_currentStep == 0 && controller.selectedFarm.value == null) {
            Get.snackbar(
              '입력 오류',
              '농가를 선택해주세요.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red.shade100,
              colorText: Colors.red.shade800,
            );
            return;
          }
          setState(() {
            _currentStep += 1;
          });
        } else {
          _submitForm();
        }
      },
      onStepCancel: () {
        if (_currentStep > 0) {
          setState(() {
            _currentStep -= 1;
          });
        }
      },
      onStepTapped: (int index) {
        setState(() {
          _currentStep = index;
        });
      },
      steps: [
        // 농가 선택 단계
        Step(
          title: const Text('농가 선택'),
          subtitle: const Text('농지를 등록할 농가를 선택해주세요'),
          content: _buildFarmSelectionStep(),
          isActive: _currentStep >= 0,
          state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        ),
        // 위치 정보 단계
        Step(
          title: const Text('위치 정보'),
          subtitle: const Text('농지의 위치 정보를 입력해주세요'),
          content: _buildLocationStep(),
          isActive: _currentStep >= 1,
          state: _currentStep > 1 ? StepState.complete : StepState.indexed,
        ),
        // 농지 정보 단계
        Step(
          title: const Text('농지 정보'),
          subtitle: const Text('농지의 면적, 작물 등 추가 정보를 입력해주세요'),
          content: _buildFieldInfoStep(),
          isActive: _currentStep >= 2,
          state: _currentStep > 2 ? StepState.complete : StepState.indexed,
        ),
      ],
    );
  }

  // 모바일용 폼
  Widget _buildMobileForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 필수 입력 안내
          _buildSectionHeader('농가 선택 (필수)', true),
          const SizedBox(height: 16),

          // 농가 선택
          _buildFarmSelectionField(),
          const SizedBox(height: 32),

          // 위치 정보 섹션
          _buildSectionHeader('위치 정보 (필수)', true),
          const SizedBox(height: 16),

          // 주소 정보
          _buildAddressFields(),
          const SizedBox(height: 32),

          // 농지 정보 섹션
          _buildSectionHeader('농지 정보 (필수)', true),
          const SizedBox(height: 16),

          // 면적 정보
          _buildAreaField(),
          const SizedBox(height: 16),

          // 작물 종류
          _buildCropTypeField(),
          const SizedBox(height: 16),

          // 수확 예정일
          _buildHarvestDateField(),
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
                '농지 등록하기',
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
    );
  }

  // 섹션 헤더
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

  // 단계 1: 농가 선택
  Widget _buildFarmSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFarmSelectionField(),
        const SizedBox(height: 16),
      ],
    );
  }

  // 농가 선택 필드
  Widget _buildFarmSelectionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '농가 선택 *',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          // 농가 목록
          final farms = farmController.farms;

          if (farms.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '등록된 농가가 없습니다.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    // 농가 등록 화면으로 이동
                    Get.toNamed('/farm/add');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('농가 등록하기'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            );
          }

          return DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              hintText: '농가 선택',
              prefixIcon: Icon(Icons.agriculture),
            ),
            value: controller.selectedFarm.value?.id,
            items: farms
                .map((farm) => DropdownMenuItem(
                      value: farm.id,
                      child: Text(farm.name),
                    ))
                .toList(),
            onChanged: (value) async {
              if (value != null) {
                await farmController.selectFarm(value);
                controller.selectedFarm.value =
                    farmController.selectedFarm.value;
              } else {
                controller.selectedFarm.value = null;
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '농가를 선택해주세요';
              }
              return null;
            },
            autovalidateMode: AutovalidateMode.onUserInteraction,
          );
        }),
      ],
    );
  }

  // 단계 2: 위치 정보
  Widget _buildLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAddressFields(),
        const SizedBox(height: 16),
      ],
    );
  }

  // 주소 필드들
  Widget _buildAddressFields() {
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
                  labelText: '주소 *',
                  prefixIcon: Icon(Icons.home),
                  hintText: '주소 검색',
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
            prefixIcon: Icon(Icons.location_on),
            hintText: '상세주소 입력',
          ),
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }

  // 단계 3: 농지 정보
  Widget _buildFieldInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAreaField(),
        const SizedBox(height: 16),
        _buildCropTypeField(),
        const SizedBox(height: 16),
        _buildHarvestDateField(),
        const SizedBox(height: 16),
        _buildMemoField(),
      ],
    );
  }

  // 면적 입력 필드
  Widget _buildAreaField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: controller.areaController,
            decoration: const InputDecoration(
              labelText: '면적 *',
              prefixIcon: Icon(Icons.straighten),
              hintText: '숫자만 입력',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            validator: Validators.validateArea,
            textInputAction: TextInputAction.next,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 1,
          child: Obx(() => DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: '단위 *',
                ),
                value: controller.selectedAreaUnit.value,
                items: controller.areaUnits
                    .map((unit) => DropdownMenuItem(
                          value: unit,
                          child: Text(unit),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    controller.selectedAreaUnit.value = value;
                  }
                },
              )),
        ),
      ],
    );
  }

  // 작물 종류 입력 필드
  Widget _buildCropTypeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '작물 종류 *',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        _isAddingNewCropType
            ? _buildNewCropTypeInput()
            : Obx(() => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          hintText: '작물 선택',
                          prefixIcon: Icon(Icons.grass),
                        ),
                        value: controller.cropTypeController.text.isEmpty
                            ? null
                            : controller.cropTypeController.text,
                        items: [
                          // 기존 작물 목록
                          ...controller.cropTypes
                              .map((crop) => DropdownMenuItem(
                                    value: crop,
                                    child: Text(crop),
                                  )),
                          // 구분선 (작물이 있는 경우에만)
                          if (controller.cropTypes.isNotEmpty)
                            const DropdownMenuItem(
                              value: '_divider_',
                              enabled: false,
                              child: Divider(),
                            ),
                          // 새 작물 추가 옵션
                          const DropdownMenuItem(
                            value: '_add_new_',
                            child: Row(
                              children: [
                                Icon(Icons.add,
                                    size: 16, color: AppTheme.primaryColor),
                                SizedBox(width: 8),
                                Text(
                                  '새 작물 추가',
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
                              _isAddingNewCropType = true;
                            });
                          } else if (value != null && value != '_divider_') {
                            controller.cropTypeController.text = value;
                          }
                        },
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              value == '_divider_' ||
                              value == '_add_new_') {
                            return '작물 종류를 선택해주세요';
                          }
                          return null;
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                    ),
                  ],
                )),
      ],
    );
  }

  // 새 작물 입력 필드
  Widget _buildNewCropTypeInput() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _newCropTypeController,
            decoration: const InputDecoration(
              hintText: '새 작물 이름',
              prefixIcon: Icon(Icons.grass),
            ),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _addNewCropType(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.check),
          onPressed: _addNewCropType,
          color: AppTheme.primaryColor,
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              _isAddingNewCropType = false;
              _newCropTypeController.clear();
            });
          },
          color: Colors.red,
        ),
      ],
    );
  }

  // 수확 예정일 필드
  Widget _buildHarvestDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '수확 예정일',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => InkWell(
              onTap: _selectHarvestDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today),
                  hintText: '수확 예정일 선택',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      controller.selectedHarvestDate.value != null
                          ? DateFormat('yyyy년 MM월 dd일')
                              .format(controller.selectedHarvestDate.value!)
                          : '수확 예정일 선택',
                      style: TextStyle(
                        color: controller.selectedHarvestDate.value != null
                            ? AppTheme.textPrimaryColor
                            : Colors.grey.shade400,
                      ),
                    ),
                    if (controller.selectedHarvestDate.value != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          controller.selectedHarvestDate.value = null;
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 20,
                      ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  // 메모 입력 필드
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
                controller.addressController.text = '경기도 수원시 영통구 광교호수공원로 277';
                Navigator.pop(context);
              },
              child: const Text('테스트 주소 사용'),
            ),
          ],
        );
      },
    );
  }

  // 수확 예정일 선택
  Future<void> _selectHarvestDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedHarvestDate.value ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      helpText: '수확 예정일 선택',
      cancelText: '취소',
      confirmText: '선택',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != controller.selectedHarvestDate.value) {
      controller.selectedHarvestDate.value = picked;
    }
  }

  // 새 작물 추가 처리
  void _addNewCropType() {
    final String newCropType = _newCropTypeController.text.trim();
    if (newCropType.isEmpty) return;

    controller.addCropType(newCropType);
    controller.cropTypeController.text = newCropType;

    setState(() {
      _isAddingNewCropType = false;
      _newCropTypeController.clear();
    });
  }

  // 폼 제출 처리
  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      // 키보드 닫기
      FocusScope.of(context).unfocus();

      // 농지 등록
      bool success = await controller.createField();

      if (success) {
        Get.back(); // 목록 화면으로 이동
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

      // 모바일 뷰에서는 스테퍼가 없으므로 스크롤만 처리
      if (MediaQuery.of(context).size.width <= 800) {
        return;
      }

      // 유효성 검사 실패 필드가 있는 스텝으로 이동
      int targetStep = _currentStep;

      // 농가 선택 검사
      if (controller.selectedFarm.value == null) {
        targetStep = 0;
      }
      // 주소 검사
      else if (controller.addressController.text.isEmpty) {
        targetStep = 1;
      }
      // 면적 및 작물 검사
      else if (controller.areaController.text.isEmpty ||
          controller.cropTypeController.text.isEmpty) {
        targetStep = 2;
      }

      if (targetStep != _currentStep) {
        setState(() {
          _currentStep = targetStep;
        });
      }
    }
  }
}
