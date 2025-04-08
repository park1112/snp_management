import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/farm_model.dart';

class FieldFilter extends StatelessWidget {
  final List<FarmModel> farms;
  final List<String> cropTypes;
  final List<String> stages;
  final String? selectedCropType;
  final String? selectedStage;
  final FarmModel? selectedFarm;
  final Function(String?) onCropTypeChanged;
  final Function(String?) onStageChanged;
  final Function(FarmModel?) onFarmChanged;
  final VoidCallback onReset;

  const FieldFilter({
    Key? key,
    required this.farms,
    required this.cropTypes,
    required this.stages,
    this.selectedCropType,
    this.selectedStage,
    this.selectedFarm,
    required this.onCropTypeChanged,
    required this.onStageChanged,
    required this.onFarmChanged,
    required this.onReset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 필터 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '필터 옵션',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('초기화'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 농가 필터
          _buildFarmFilter(),
          const SizedBox(height: 16),

          // 작물 종류 필터
          _buildFilterSection(
            '작물 종류',
            cropTypes,
            selectedCropType,
            onCropTypeChanged,
          ),
          const SizedBox(height: 16),

          // 작업 단계 필터
          _buildFilterSection(
            '작업 단계',
            stages,
            selectedStage,
            onStageChanged,
          ),
        ],
      ),
    );
  }

  // 농가 필터 섹션
  Widget _buildFarmFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '농가',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        if (farms.isEmpty)
          Text(
            '농가가 없습니다',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedFarm?.id,
                icon: const Icon(Icons.arrow_drop_down),
                iconEnabledColor: AppTheme.primaryColor,
                isExpanded: true,
                hint: Text(
                  '농가 선택',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textPrimaryColor,
                ),
                onChanged: (String? farmId) {
                  if (farmId == null || farmId.isEmpty) {
                    onFarmChanged(null);
                  } else {
                    final farm = farms.firstWhere(
                      (f) => f.id == farmId,
                      orElse: () => throw Exception('농가를 찾을 수 없습니다'),
                    );
                    onFarmChanged(farm);
                  }
                },
                items: [
                  // '전체' 항목 추가
                  DropdownMenuItem<String>(
                    value: '',
                    child: Text(
                      '전체',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // 구분선
                  DropdownMenuItem<String>(
                    enabled: false,
                    child: Divider(color: Colors.grey.shade300),
                  ),
                  // 실제 농가 목록
                  ...farms.map((farm) {
                    return DropdownMenuItem<String>(
                      value: farm.id,
                      child: Text(farm.name),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // 필터 섹션 위젯 (재사용 가능)
  Widget _buildFilterSection(
    String title,
    List<String> items,
    String? selectedItem,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text(
            '항목이 없습니다',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedItem,
                icon: const Icon(Icons.arrow_drop_down),
                iconEnabledColor: AppTheme.primaryColor,
                isExpanded: true,
                hint: Text(
                  '선택해주세요',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textPrimaryColor,
                ),
                onChanged: onChanged,
                items: [
                  // '전체' 항목 추가
                  DropdownMenuItem<String>(
                    value: '',
                    child: Text(
                      '전체',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // 구분선
                  DropdownMenuItem<String>(
                    enabled: false,
                    child: Divider(color: Colors.grey.shade300),
                  ),
                  // 실제 아이템 목록
                  ...items.map((String item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// 필터 모달 다이얼로그 래퍼
class FieldFilterModal extends StatelessWidget {
  final List<FarmModel> farms;
  final List<String> cropTypes;
  final List<String> stages;
  final String? selectedCropType;
  final String? selectedStage;
  final FarmModel? selectedFarm;
  final Function(String?) onCropTypeChanged;
  final Function(String?) onStageChanged;
  final Function(FarmModel?) onFarmChanged;
  final VoidCallback onReset;
  final VoidCallback onApply;

  const FieldFilterModal({
    Key? key,
    required this.farms,
    required this.cropTypes,
    required this.stages,
    this.selectedCropType,
    this.selectedStage,
    this.selectedFarm,
    required this.onCropTypeChanged,
    required this.onStageChanged,
    required this.onFarmChanged,
    required this.onReset,
    required this.onApply,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 필터 내용
            FieldFilter(
              farms: farms,
              cropTypes: cropTypes,
              stages: stages,
              selectedCropType: selectedCropType,
              selectedStage: selectedStage,
              selectedFarm: selectedFarm,
              onCropTypeChanged: onCropTypeChanged,
              onStageChanged: onStageChanged,
              onFarmChanged: onFarmChanged,
              onReset: onReset,
            ),
            const SizedBox(height: 16),

            // 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('취소'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    onApply();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('적용'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
